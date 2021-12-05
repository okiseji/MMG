%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%             OPTIONS AND PROCESS                %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Options=struct('Convert',1,'X_Reverse',0,'Y_Reverse',0,'NumberString_StationID',0,'Number_LineID',0,'NumberString_LineID',0,'LineOrientedData',1);
DrawOptions=struct('Draw',1,'Zoom',1,'Text',0,'ERROR',0.003,'LINE_WIDTH',5,'STATION_SIZE',30,'STATION_EDGE_WIDTH',1,'FONT_SIZE',10,'EXCHANGE_POWER',30);
main('CS1.json',Options,DrawOptions);
% mainload('Lisboa');
% presentation('Berlin',0);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                 MAIN FUNCTION                  %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\
function presentation(CITY_NAME,CONVERT)
    if CONVERT==1
        load('Berlin.mat','graph','color');
        [Nvx,Nvy]=createGenerateLP(graph);
        Ngraph=graph;
        for i=1:numel(Ngraph.nodes)
            Ngraph.nodes(i).metadata.x=Nvx(i);
            Ngraph.nodes(i).metadata.y=Nvy(i);
        end
        load(append(CITY_NAME,'_Converted_DrawOptions.mat'),'DrawOptions');
        draw_map(Ngraph,color,DrawOptions);
    else
        load(append(CITY_NAME,'_DrawOptions.mat'),'DrawOptions');
        load(append(CITY_NAME,'.mat'),'graph','color');
        draw_map(graph,color,DrawOptions);
    end
end
function mainload(CITY_NAME)
    load(append(CITY_NAME,'_Converted.mat'),'Ngraph','color');
    load(append(CITY_NAME,'_Converted_DrawOptions.mat'),'DrawOptions');
    draw_map(Ngraph,color,DrawOptions);
    load(append(CITY_NAME,'_DrawOptions.mat'),'DrawOptions');
    load(append(CITY_NAME,'.mat'),'graph','color');
    draw_map(graph,color,DrawOptions);
end
function main(FileName,Options,DrawOptions)
    % options initialize
    Convert=Options.Convert;
    X_Reverse=Options.X_Reverse;
    Y_Reverse=Options.Y_Reverse;
    NumberString_StationID=Options.NumberString_StationID;
    Number_LineID=Options.Number_LineID;
    NumberString_LineID=Options.NumberString_LineID;
    LineOrientedData=Options.LineOrientedData;
    % read json file and create graph data
    str=fileread(FileName);
    original_graph=jsondecode(str);
    % data preprocessing by options
    if LineOrientedData==1
        color=find_color(original_graph);
        graph=sortdata(original_graph);
    else
        graph=original_graph;
        for i=1:numel(graph.nodes)
            id=graph.nodes(i).id;
            x=graph.nodes(i).metadata.x;
            y=graph.nodes(i).metadata.y;
            if NumberString_StationID==1
                graph.nodes(i).id=str2double(id);
            end
            if X_Reverse==1
                graph.nodes(i).metadata.x=10000-x;
            end
            if Y_Reverse==1
                graph.nodes(i).metadata.y=10000-y;
            end 
        end
        for i=1:numel(graph.edges)
            source=graph.edges(i).source;
            target=graph.edges(i).target;
            lines=graph.edges(i).metadata.lines;
            if NumberString_StationID==1
                graph.edges(i).source=str2double(source);
                graph.edges(i).target=str2double(target);
            end
            if Number_LineID==1
                Nlines={};
                for j=1:numel(lines)
                    line=lines(j);
                    Nline=append('L',num2str(line));
                    Nlines{end+1}=Nline;
                end
                graph.edges(i).metadata.lines=Nlines;
            end
            if NumberString_LineID==1
                Nlines={};
                for j=1:numel(lines)
                    line=lines(j);
                    Nline=append('L',line);
                    Nlines{end+1}=Nline;
                end
                graph.edges(i).metadata.lines=Nlines;
            end
        end
        for i=1:numel(graph.lines)
            id=graph.lines(i).id;
            if Number_LineID==1
                graph.lines(i).id=append('L',num2str(id));
            end
            if NumberString_LineID==1
                graph.lines(i).id=append('L',id);
            end
        end
        color=find_color(graph);
    end
    if Convert==0
        % original map drawing
        if DrawOptions.Draw==1
            draw_map(graph,color,DrawOptions);
        end
    else
        % convert map drawing
        [Nvx,Nvy]=createGenerateLP(graph);
        Ngraph=graph;
        for i=1:numel(Ngraph.nodes)
            Ngraph.nodes(i).metadata.x=Nvx(i);
            Ngraph.nodes(i).metadata.y=Nvy(i);
        end
        if DrawOptions.Draw==1
            draw_map(Ngraph,color,DrawOptions);
        end
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                    DRAW MAP                    %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function draw_map(graph,color,DrawOptions)
    Zoom=DrawOptions.Zoom;
    TEXT=DrawOptions.Text;
    ERROR=DrawOptions.ERROR;
    LINE_WIDTH=DrawOptions.LINE_WIDTH;
    STATION_SIZE=DrawOptions.STATION_SIZE;
    STATION_EDGE_WIDTH=DrawOptions.STATION_EDGE_WIDTH;
    EXCHANGE_POWER=DrawOptions.EXCHANGE_POWER;
    FONT_SIZE=DrawOptions.FONT_SIZE;
    scr_siz = get(0,'ScreenSize') ;
    if Zoom==1
        figure('Name','METRO MAP','NumberTitle','off');
    else
        figure('Name','METRO MAP','NumberTitle','off','Menu','none','ToolBar','none');
    end
    DirectedLines=createDirectedLine(graph,color);
    lines=fieldnames(DirectedLines);
    TrackPos=cell(length(graph.edges),1);
    for i=1:numel(lines)
        line=lines{i};
        route=DirectedLines.(line);
        index=0;
        for j=1:numel(route)
            edge=route{j};
            beforeIndex=index;
            index=edgeIndex(graph,edge);
            if isempty(TrackPos{index})
                % M is empty, fill M
                TrackPos{index}=cell(9,1);           
                TrackPos{index}{1,1}=line;
                TrackPos{index}{1,2}=edge.source;
                TrackPos{index}{1,3}=edge.target;
                TrackPos{index}{1,4}=beforeIndex;
            else
                if beforeIndex==0
                    % if vice track is at start, set it R generally
                    q=1;
                    while TrackPos{index}{2,q}~=0
                        q=q+1;
                    end
                    Rlen=q-1;
                    TrackPos{index}{2,Rlen+1}=line;
                    TrackPos{index}{3,Rlen+1}=edge.source;
                    TrackPos{index}{4,Rlen+1}=edge.target;
                    TrackPos{index}{5,Rlen+1}=beforeIndex;
                else
                    % if former vice track exist check former main track
                    MbeforeIndex=TrackPos{index}{1,4};
                    [Vsource,Vtarget]=findVecbyCell(TrackPos{beforeIndex},line);
                    if MbeforeIndex==0
                        % if former main track not exist just compare 
                        % this main track with former vice track
                        Msource=TrackPos{index}{1,2};
                        Mtarget=TrackPos{index}{1,3};
                        right=checkRight(graph,Msource,Mtarget,Vsource,Vtarget);
                        q=1;
                        while TrackPos{index}{2,q}~=0
                            q=q+1;
                        end
                        Rlen=q-1;
                        q=1;
                        while TrackPos{index}{6,q}~=0
                            q=q+1;
                        end
                        Llen=q-1;
                        if right==1
                            TrackPos{index}{2,Rlen+1}=line;
                            TrackPos{index}{3,Rlen+1}=edge.source;
                            TrackPos{index}{4,Rlen+1}=edge.target;
                            TrackPos{index}{5,Rlen+1}=beforeIndex;
                        else
                            TrackPos{index}{6,Llen+1}=line;
                            TrackPos{index}{7,Llen+1}=edge.source;
                            TrackPos{index}{8,Llen+1}=edge.target;
                            TrackPos{index}{9,Llen+1}=beforeIndex;
                        end
                    else
                        % if former main track exist just compare 
                        % former main track with former vice track
                        Mline=TrackPos{index}{1,1};
                        [Msource,Mtarget]=findVecbyCell(TrackPos{MbeforeIndex},line);
                        if Msource~=0 && Mtarget~=0
                            % if the edge of former main track has vice
                            % track ,inherit relation in former common track
                            right=checkRightByCell(TrackPos{MbeforeIndex},Mline,line);
                            q=1;
                            while TrackPos{index}{2,q}~=0
                                q=q+1;
                            end
                            Rlen=q-1;
                            q=1;
                            while TrackPos{index}{6,q}~=0
                                q=q+1;
                            end
                            Llen=q-1;
                            if right==1
                                TrackPos{index}{2,Rlen+1}=line;
                                TrackPos{index}{3,Rlen+1}=edge.source;
                                TrackPos{index}{4,Rlen+1}=edge.target;
                                TrackPos{index}{5,Rlen+1}=beforeIndex;
                            else
                                TrackPos{index}{6,Llen+1}=line;
                                TrackPos{index}{7,Llen+1}=edge.source;
                                TrackPos{index}{8,Llen+1}=edge.target;
                                TrackPos{index}{9,Llen+1}=beforeIndex;
                            end
                        else
                            % two former tarck are both distinct
                            [Msource,Mtarget]=findVecbyCell(TrackPos{MbeforeIndex},Mline);
                            right=checkRight(graph,Msource,Mtarget,Vsource,Vtarget);
                            q=1;
                            while TrackPos{index}{2,q}~=0
                                q=q+1;
                            end
                            Rlen=q-1;
                            q=1;
                            while TrackPos{index}{6,q}~=0
                                q=q+1;
                            end
                            Llen=q-1;
                            if right==1
                                TrackPos{index}{2,Rlen+1}=line;
                                TrackPos{index}{3,Rlen+1}=edge.source;
                                TrackPos{index}{4,Rlen+1}=edge.target;
                                TrackPos{index}{5,Rlen+1}=beforeIndex;
                            else
                                TrackPos{index}{6,Llen+1}=line;
                                TrackPos{index}{7,Llen+1}=edge.source;
                                TrackPos{index}{8,Llen+1}=edge.target;
                                TrackPos{index}{9,Llen+1}=beforeIndex;
                            end
                        end
                    end
                end
            end
        end
    end
    labels='';
    for k=1:numel(TrackPos)
        cellMatrix=TrackPos{k};
        i=1;
        while cellMatrix{2,i}~=0
            i=i+1;
        end
        Rlen=i-1;
        i=1;
        while cellMatrix{6,i}~=0
            i=i+1;
        end
        Llen=i-1;
        tracks={};
        for i=1:Llen
            tracks{end+1}=cellMatrix{6,i};
        end
        tracks{end+1}=cellMatrix{1,1};
        for i=1:Rlen
            tracks{end+1}=cellMatrix{2,i};
        end
        source=cellMatrix{1,2};
        target=cellMatrix{1,3};
        sx=graph.nodes(nodeIndex(graph,source)).metadata.x;
        sy=graph.nodes(nodeIndex(graph,source)).metadata.y;
        tx=graph.nodes(nodeIndex(graph,target)).metadata.x;
        ty=graph.nodes(nodeIndex(graph,target)).metadata.y;
        X=tx-sx;
        Y=ty-sy;
        right=[Y,-X]/norm([Y,-X]);
        for i=1:numel(tracks)
            weight=right*(i-(numel(tracks)+1)/2)*ERROR;
            x=[sx,tx]+weight(1)*[1,1];
            y=[sy,ty]+weight(2)*[1,1];
            label=tracks{i};
            colorstr=color.(tracks{i});
            [rgb, ~] = matlab.graphics.internal.convertToRGB([colorstr]);
            if regexp(labels,label)
                legend('AutoUpdate','off');
                plot(x,y,'Color',rgb,'LineWidth',LINE_WIDTH);
            else
                legend('AutoUpdate','on');
                plot(x,y,'Color',rgb,'LineWidth',LINE_WIDTH,'DisplayName',label);
                labels=append(labels,label);
            end
            hold all;
        end
    end
    for i=1:numel(graph.nodes)
        station=graph.nodes(i);
        if findExchange(graph,station.id)>2
            SIZE=findExchange(graph,station.id);
            scatter(station.metadata.x,station.metadata.y,STATION_SIZE+SIZE*EXCHANGE_POWER,'s','MarkerEdgeColor',[0 0 0],'MarkerFaceColor',[1 1 1],'LineWidth',STATION_EDGE_WIDTH);
            if TEXT==1
                text(station.metadata.x,station.metadata.y,append('  ',station.label),'FontSize',FONT_SIZE+1);
            end
        else
            scatter(station.metadata.x,station.metadata.y,STATION_SIZE,'MarkerEdgeColor',[0 0 0],'MarkerFaceColor',[1 1 1],'LineWidth',STATION_EDGE_WIDTH);
            if TEXT==1
                text(station.metadata.x,station.metadata.y,append('  ',station.label),'FontSize',FONT_SIZE);
            end
        end
        hold all;
    end
    grid off;
    axis off;
    axis equal;
    set(gcf,'color','w','Position',floor([(scr_siz(3)-scr_siz(4)-400)/2 0 scr_siz(4)+400 scr_siz(4)]));
end
function right=checkRight(graph,Msource,Mtarget,Vsource,Vtarget)
    msx=graph.nodes(nodeIndex(graph,Msource)).metadata.x;
    msy=graph.nodes(nodeIndex(graph,Msource)).metadata.y;
    mtx=graph.nodes(nodeIndex(graph,Mtarget)).metadata.x;
    mty=graph.nodes(nodeIndex(graph,Mtarget)).metadata.y;
    x1=mtx-msx;
    y1=mty-msy;
    vsx=graph.nodes(nodeIndex(graph,Vsource)).metadata.x;
    vsy=graph.nodes(nodeIndex(graph,Vsource)).metadata.y;
    vtx=graph.nodes(nodeIndex(graph,Vtarget)).metadata.x;
    vty=graph.nodes(nodeIndex(graph,Vtarget)).metadata.y;
    x2=vtx-vsx;
    y2=vty-vsy;
    if -x1*y2+y1*x2>0
        right=0;
    else
        right=1;
    end
end
function [source,target]=findVecbyCell(cellMatrix,line)
    i=1;
    while cellMatrix{2,i}~=0
        i=i+1;
    end
    Rlen=i-1;
    i=1;
    while cellMatrix{6,i}~=0
        i=i+1;
    end
    Llen=i-1;
    if cellMatrix{1,1}==line
        source=cellMatrix{1,2};
        target=cellMatrix{1,3};
        return
    end
    for i=1:Rlen
        if cellMatrix{2,i}==line
            source=cellMatrix{3,i};
            target=cellMatrix{4,i};
            return
        end
    end
    for i=1:Llen
        if cellMatrix{6,i}==line
            source=cellMatrix{7,i};
            target=cellMatrix{8,i};
            return
        end
    end
    source=0;
    target=0;
end
function right=checkRightByCell(cellMatrix,Mline,line)
    i=1;
    while cellMatrix{2,i}~=0
        i=i+1;
    end
    Rlen=i-1;
    i=1;
    while cellMatrix{6,i}~=0
        i=i+1;
    end
    Llen=i-1;
    if cellMatrix{1,1}==Mline
        M=0;
    end
    for i=1:Rlen
        if cellMatrix{2,i}==Mline
            M=i;
        elseif cellMatrix{2,i}==line
            V=i;
        end
    end
    for i=1:Llen
        if cellMatrix{6,i}==Mline
            M=-i;
        elseif cellMatrix{6,i}==line
            V=-i;
        end
    end
    if M>V
        right=0;
    else
        right=1;
    end
end
function DirectedLines=createDirectedLine(graph,color)
    DirectedLines=struct();
    lines=fieldnames(color);
    for i=1:numel(lines)
        line=lines{i};
        for j=1:numel(graph.edges)
            edge=graph.edges(j);
            AddedLines=fieldnames(DirectedLines);
            if any(strcmp(edge.metadata.lines,line)) && ~any(strcmp(AddedLines,line))
                FullLine=findFullLine(graph,edge,line);
                DirectedLines.(line)=FullLine;
            end
        end
    end
end
function FullLine=findFullLine(graph,edge,line)
    CentreEdge=edge;
    before={};
    after={};
    while class(FindBefore(graph,edge,line))=='struct'
        edge=FindBefore(graph,edge,line);
        before{end+1}=edge;
    end
    edge=CentreEdge;
    while class(FindAfter(graph,edge,line))=='struct'
        edge=FindAfter(graph,edge,line);
        after{end+1}=edge;
    end
    FullLine={};
    before=flip(before);
    for i=1:numel(before)
        FullLine{end+1}=before{i};
    end
    FullLine{end+1}=CentreEdge;
    for j=1:numel(after)
        FullLine{end+1}=after{j};
    end
end
function before=FindBefore(graph,edge,line)
    for i=1:numel(graph.edges)
        target=graph.edges(i).target;
        source=graph.edges(i).source;
        lines=graph.edges(i).metadata.lines;
        if (target==edge.source || source==edge.source) && any(strcmp(lines,line)) && ~(source==edge.source && target==edge.target)&&~(target==edge.source && source==edge.target)
            before=graph.edges(i);
            if before.target==edge.source
                return
            else
                before.target=source;
                before.source=target;
                return
            end
        end
    end
    before=0;
end
function after=FindAfter(graph,edge,line)
    for i=1:numel(graph.edges)
        target=graph.edges(i).target;
        source=graph.edges(i).source;
        lines=graph.edges(i).metadata.lines;
        if (target==edge.target || source==edge.target) && any(strcmp(lines,line)) && ~(source==edge.source && target==edge.target)&&~(target==edge.source && source==edge.target)
            after=graph.edges(i);
            if after.source==edge.target
                return
            else
                after.target=source;
                after.source=target;
                return
            end
        end
    end
    after=0;
end
function index=findExchange(graph,nodeId)
    index=0;
    for i=1:length(graph.edges)
        if nodeId==graph.edges(i).source || nodeId==graph.edges(i).target
            index=index+numel(graph.edges(i).metadata.lines);
        end
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                   SORT DATA                    %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function graph=sortdata(data)
    graph.nodes=data.nodes;
    k=1;
    graph.edges=struct([]);
    for i=1:numel(data.lines)
        for j=1:numel(data.lines(i).route)-1
            source=data.lines(i).route(j);
            target=data.lines(i).route(j+1);
            RepeatIndex=findRepeat(graph.edges,source,target);
            if RepeatIndex==0
                graph.edges(k,1).source=data.lines(i).route(j);
                graph.edges(k,1).target=data.lines(i).route(j+1);
                graph.edges(k,1).metadata.lines={data.lines(i).id};
                k=k+1;
            else
                graph.edges(RepeatIndex,1).metadata.lines{end+1}=data.lines(i).id;
            end
        end
    end
end
function RepeatIndex=findRepeat(edges,source,target)
    if isempty(edges)
        RepeatIndex=0;
        return
    end
    for i=1:length(edges)
        edge=edges(i);
        if (edge.source==source && edge.target==target) || (edge.source==target && edge.target==source)
            RepeatIndex=i;
            return
        end
    end
    RepeatIndex=0;
end
function color=find_color(graph)
    for i=1:numel(graph.lines)
        line=graph.lines(i);
        color.(line.id)=line.color;
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%           PREPARE FOR　DIRECTIONS              %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 9 o'clock = 0/8, 6 o'clock = 2, 3 o'clock = 4, 12 o'clock = 6
function angle=ang(vector)
    angle=4*((atan2(vector.y,vector.x)/pi)+1);
end
% find 2 directions
function closestDirections=closestDirectionIds(angle)
    mainDirection=mod(round(angle),8);
    if (round(angle)-angle)>0
        secondaryDirection=mod(round(angle)-1,8);
    else
        secondaryDirection=mod(round(angle)+1,8);
    end
    closestDirections=[mainDirection,secondaryDirection];
end
function graph=addDirection(graph)
    for i=1:length(graph.edges)
        source=graph.nodes(nodeIndex(graph,graph.edges(i).source)).metadata;
        target=graph.nodes(nodeIndex(graph,graph.edges(i).target)).metadata;
        vector=struct('x',target.x-source.x,'y',target.y-source.y);
        angle=ang(vector);
        graph.edges(i).sourceDirections=closestDirectionIds(angle);
        graph.edges(i).targetDirections=mod(graph.edges(i).sourceDirections+4,8);
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                FIND SOME INDEX                 %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function index=nodeIndex(graph,nodeId)
    for i=1:length(graph.nodes)
        if nodeId==graph.nodes(i).id
            index=i;
            return
        end
    end
end
function index=edgeIndex(graph,edge)
    for i=1:length(graph.edges)
        if (edge.source==graph.edges(i).source && edge.target == graph.edges(i).target) || (edge.target==graph.edges(i).source && edge.source == graph.edges(i).target)
            index=i;
            return
        end
    end
end
function index=degree(graph,nodeId)
    index=0;
    for i=1:length(graph.edges)
        if nodeId==graph.edges(i).source || nodeId==graph.edges(i).target
            index=index+1;
        end
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%           OctolinearityConstraints             %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function cons=createSetProduct(cons,settings,product,continuous,binary)
    upperBound=settings.maxEdgeLength+1;
    upperBound=sprintf('%d',upperBound);
    cons{end+1}=append(product,'-',upperBound,'*',binary,'<=0');
    cons{end+1}=append(product,'-',continuous,'<=0');
    cons{end+1}=append(product,'-',continuous,'-',upperBound,'*',binary,'>=-',upperBound);
end
function cons=createOctolinearityConstraints(cons,settings,graph,edge)
    mainDirection=edge.sourceDirections(1);
    secondaryDirection=edge.sourceDirections(2);
    s=nodeIndex(graph,edge.source);
    t=nodeIndex(graph,edge.target);
    e=edgeIndex(graph,edge);
    s=sprintf('(%d)',s);
    t=sprintf('(%d)',t);
    e=sprintf('(%d)',e);
    cons=createSetProduct(cons,settings,append('pa',e),append('l',e),append('a',e));
    cons=createSetProduct(cons,settings,append('pb',e),append('l',e),append('b',e));
    cons=createSetProduct(cons,settings,append('pc',e),append('l',e),append('c',e));
    cons=createSetProduct(cons,settings,append('pd',e),append('l',e),append('d',e));
    cons{end+1}=append('vx',t,'-vx',s,'-pa',e,'+pb',e,'==0');
    cons{end+1}=append('vy',t,'-vy',s,'-pc',e,'+pd',e,'==0');
    cons{end+1}=append('a',e,'+b',e,'<=1');
    cons{end+1}=append('c',e,'+d',e,'<=1');
    switch mainDirection
        case 0
            cons{end+1}=append('a',e,'==0');
            cons{end+1}=append('b',e,'==1');
            if secondaryDirection==7
                cons{end+1}=append('d',e,'==0');
            elseif secondaryDirection==1
                cons{end+1}=append('c',e,'==0');
            end
        case 1
            cons{end+1}=append('a',e,'==0');
            cons{end+1}=append('c',e,'==0');
            if secondaryDirection==2
                cons{end+1}=append('d',e,'==1');
            elseif secondaryDirection==0
                cons{end+1}=append('b',e,'==1');
            end
        case 2
            cons{end+1}=append('c',e,'==0');
            cons{end+1}=append('d',e,'==1');
            if secondaryDirection==3
                cons{end+1}=append('b',e,'==0');
            elseif secondaryDirection==1
                cons{end+1}=append('a',e,'==0');
            end
        case 3
            cons{end+1}=append('b',e,'==0');
            cons{end+1}=append('c',e,'==0');
            if secondaryDirection==4
                cons{end+1}=append('a',e,'==1');
            elseif secondaryDirection==2
                cons{end+1}=append('d',e,'==1');
            end
        case 4
            cons{end+1}=append('a',e,'==1');
            cons{end+1}=append('b',e,'==0');
            if secondaryDirection==5
                cons{end+1}=append('d',e,'==0');
            elseif secondaryDirection==3
                cons{end+1}=append('c',e,'==0');
            end
        case 5
            cons{end+1}=append('b',e,'==0');
            cons{end+1}=append('d',e,'==0');
            if secondaryDirection==6
                cons{end+1}=append('c',e,'==1');
            elseif secondaryDirection==4
                cons{end+1}=append('a',e,'==1');
            end
        case 6
            cons{end+1}=append('c',e,'==1');
            cons{end+1}=append('d',e,'==0');
            if secondaryDirection==7
                cons{end+1}=append('a',e,'==0');
            elseif secondaryDirection==5
                cons{end+1}=append('b',e,'==0');
            end
        case 7
            cons{end+1}=append('a',e,'==0');
            cons{end+1}=append('d',e,'==0');
            if secondaryDirection==0
                cons{end+1}=append('b',e,'==1');
            elseif secondaryDirection==6
                cons{end+1}=append('c',e,'==1');
            end
    end
    % force angle to 180° for some pairs of adjacent edges
    adjacentLineEdges=findAdjacentLineEdges(graph,edge);
    for i=1:length(adjacentLineEdges)
        aedge=adjacentLineEdges{i};
        degrees=[degree(graph,edge.source),degree(graph,edge.target),degree(graph,aedge.source),degree(graph,aedge.target)];
        if degrees==[2,2,2,2]
            aedgeIndex=sprintf('(%d)',edgeIndex(graph,aedge));
            if edge.target==aedge.source || edge.source==aedge.target
                if aedge.sourceDirections==edge.sourceDirections
                    cons{end+1}=append('a',e,'-a',aedgeIndex,'==0');
                    cons{end+1}=append('b',e,'-b',aedgeIndex,'==0');
                    cons{end+1}=append('c',e,'-c',aedgeIndex,'==0');
                    cons{end+1}=append('d',e,'-d',aedgeIndex,'==0');
                end
            else
                if aedge.sourceDirections==edge.sourceDirections
                    cons{end+1}=append('a',e,'-b',aedgeIndex,'==0');
                    cons{end+1}=append('b',e,'-a',aedgeIndex,'==0');
                    cons{end+1}=append('c',e,'-d',aedgeIndex,'==0');
                    cons{end+1}=append('d',e,'-c',aedgeIndex,'==0');
                end
            end 
        end
    end
end
function aedges=findAdjacentLineEdges(graph,edge)
    aedges={};
    lines=edge.metadata.lines;
    coords=[edge.source,edge.target];
    for i=1:length(graph.edges)
        e=graph.edges(i);
        if ~isempty(lines(ismember(lines,e.metadata.lines))) && length(intersect(coords,[e.source,e.target]))==1
            aedges{end+1}=e;
        end
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%             OcclusionConstraints               %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function cons=createOcclusionConstraints(cons,graph,edge1,edge2)
    e1source=edge1.source;
    e1SIndex=nodeIndex(graph,e1source);
    e1S=graph.nodes(e1SIndex).metadata;
    e1target=edge1.target;
    e1TIndex=nodeIndex(graph,e1target);
    e1T=graph.nodes(e1TIndex).metadata;
    e2SIndex=nodeIndex(graph,edge2.source);
    e2S=graph.nodes(e2SIndex).metadata;
    e2TIndex=nodeIndex(graph,edge2.target);
    e2T=graph.nodes(e2TIndex).metadata;
    directionDistances=struct('west_east', [e1S.x - e2S.x, e1S.x - e2T.x, e1T.x - e2S.x, e1T.x - e2T.x],...
        'south_north', [e1S.y - e2S.y, e1S.y - e2T.y, e1T.y - e2S.y, e1T.y - e2T.y],...
        'southwest_northeast', [(e1S.x - e1S.y) - (e2S.x - e2S.y), (e1S.x - e1S.y) - (e2T.x - e2T.y), (e1T.x - e1T.y) - (e2S.x - e2S.y), (e1T.x - e1T.y) - (e2T.x - e2T.y)],...
        'northwest_southeast', [(e1S.x + e1S.y) - (e2S.x + e2S.y), (e1S.x + e1S.y) - (e2T.x + e2T.y), (e1T.x + e1T.y) - (e2S.x + e2S.y), (e1T.x + e1T.y) - (e2T.x + e2T.y)]...
    );
    directionFacts=struct();
    fn=fieldnames(directionDistances);
    for k=1:numel(fn)
        direction=fn{k};
        directionFacts.(direction).positive=sum(directionDistances.(direction)>0);
        directionFacts.(direction).closestIfSeparate=min(abs(directionDistances.(direction)));
    end
    % check if ordering in given direction is the same for all station pairs of edges and pick direction with longest distance if any fits those criteria
    best={};
    for k=1:numel(fn)
        direction=fn{k};
        if directionFacts.(direction).positive==4 || directionFacts.(direction).positive==0
            best{end+1}=direction;
        end
    end
    closestIfSeparateList=[];
    if ~isempty(best)
        for k=1:numel(best)
            closestIfSeparateList(end+1)=directionFacts.(best{k}).closestIfSeparate;
        end
    end
    [~,index]=max(closestIfSeparateList);
    preferredDirection=best{index};
    if preferredDirection
        minDist='1';
        e1SIndex=sprintf('(%d)',e1SIndex);
        e1TIndex=sprintf('(%d)',e1TIndex);
        e2SIndex=sprintf('(%d)',e2SIndex);
        e2TIndex=sprintf('(%d)',e2TIndex);
        if directionFacts.(preferredDirection).positive>=3
            endString=append('>=',minDist);
        else
            endString=append('<=-',minDist);
        end
        switch preferredDirection
            case 'west_east'
                cons{end+1}=append('vx',e1SIndex,'-vx',e2SIndex,endString);
                cons{end+1}=append('vx',e1SIndex,'-vx',e2TIndex,endString);
                cons{end+1}=append('vx',e1TIndex,'-vx',e2SIndex,endString);
                cons{end+1}=append('vx',e1TIndex,'-vx',e2TIndex,endString);
            case 'south_north'
                cons{end+1}=append('vy',e1SIndex,'-vy',e2SIndex,endString);
                cons{end+1}=append('vy',e1SIndex,'-vy',e2TIndex,endString);
                cons{end+1}=append('vy',e1TIndex,'-vy',e2SIndex,endString);
                cons{end+1}=append('vy',e1TIndex,'-vy',e2TIndex,endString);
            case 'southwest_northeast'
                cons{end+1}=append('vx',e1SIndex,'-vy',e1SIndex,'-vx',e2SIndex,'+vy',e2SIndex,endString);
                cons{end+1}=append('vx',e1SIndex,'-vy',e1SIndex,'-vx',e2TIndex,'+vy',e2TIndex,endString);
                cons{end+1}=append('vx',e1TIndex,'-vy',e1TIndex,'-vx',e2SIndex,'+vy',e2SIndex,endString);
                cons{end+1}=append('vx',e1TIndex,'-vy',e1TIndex,'-vx',e2TIndex,'+vy',e2TIndex,endString);
            case 'northwest_southeast'
                cons{end+1}=append('vx',e1SIndex,'+vy',e1SIndex,'-vx',e2SIndex,'-vy',e2SIndex,endString);
                cons{end+1}=append('vx',e1SIndex,'+vy',e1SIndex,'-vx',e2TIndex,'-vy',e2TIndex,endString);
                cons{end+1}=append('vx',e1TIndex,'+vy',e1TIndex,'-vx',e2SIndex,'-vy',e2SIndex,endString);
                cons{end+1}=append('vx',e1TIndex,'+vy',e1TIndex,'-vx',e2TIndex,'-vy',e2TIndex,endString);
        end
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%              DEAL WITH ALL DATA                %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function cons=createNotEqual(cons,settings,left,negativeRight,boolean)
    upperBound=settings.maxEdgeLength+1;
    upperBound=sprintf('%d',upperBound);
    upperBound_2=sprintf('%d',0.5-upperBound);
    cons{end+1}=append(left,negativeRight,'-',upperBound,'*',boolean,'<=0.5');
    cons{end+1}=append(left,negativeRight,'-',upperBound,'*',boolean,'>=',upperBound_2);
end
function variableList=createVariableList(graph,pre,type)
    variableList={};
    if type=='node'  
        for i=1:numel(graph.nodes)
            variableList{end+1}=append(pre,sprintf('(%d)',nodeIndex(graph,graph.nodes(i).id)));
        end
    elseif type=='edge'
        for i=1:numel(graph.edges)
            variableList{end+1}=append(pre,sprintf('(%d)',edgeIndex(graph,graph.edges(i))));
        end
    end  
end
function [Nvx,Nvy]=createGenerateLP(graph)
    settings = struct('offset',10000,'maxWidth',300,'maxHeight',300,'minEdgeLength',1,'maxEdgeLength',8);
    graph=addDirection(graph);
    % prepare variables
    coefficients=struct('q',{{}});
    continuous=struct(...
        'vx',{createVariableList(graph,'vx','node')},...
        'vy',{createVariableList(graph,'vy','node')},...
        'l',{createVariableList(graph,'l','edge')},...
        'pa',{createVariableList(graph,'pa','edge')},...
        'pb',{createVariableList(graph,'pb','edge')},...
        'pc',{createVariableList(graph,'pc','edge')},...
        'pd',{createVariableList(graph,'pd','edge')});
    integer=struct('q',{{}});
    binary=struct(...
        'a',{createVariableList(graph,'a','edge')},...
        'b',{createVariableList(graph,'b','edge')},...
        'c',{createVariableList(graph,'c','edge')},...
        'd',{createVariableList(graph,'d','edge')},...
        'h',{{}},'oa',{{}},'ob',{{}},'oc',{{}},'od',{{}},'ua',{{}},'ub',{{}},'uc',{{}},'ud',{{}});
    % prepare constraints
    cons={};
    % generate model
    % octolinearity and edge length
    for i=1:numel(graph.edges)
        edge=graph.edges(i);
        cons=createOctolinearityConstraints(cons,settings,graph,edge);
    end
    % edge occlusion
    numAdjacentEdgeConstraints=1;
    NumOfEdges=numel(graph.edges);
    for outerIndex=1:NumOfEdges
        for innerIndex=outerIndex+1:NumOfEdges
            outer=graph.edges(outerIndex);
            inner=graph.edges(innerIndex);
            % check if adjancent
            if ~isempty(intersect([outer.source,outer.target],[inner.source,inner.target]))
                num=sprintf('(%d)',numAdjacentEdgeConstraints);
                o=sprintf('(%d)',outerIndex);
                i=sprintf('(%d)',innerIndex);
                binary.h{end+1}=append('h',num);
                binary.oa{end+1}=append('oa',num);
                binary.ob{end+1}=append('ob',num);
                binary.oc{end+1}=append('oc',num);
                binary.od{end+1}=append('od',num);
                binary.ua{end+1}=append('ua',num);
                binary.ub{end+1}=append('ub',num);
                binary.uc{end+1}=append('uc',num);
                binary.ud{end+1}=append('ud',num);
                integer.q{end+1}=append('q',num);
                outermetadata=outer.metadata;
                lines=outermetadata.lines;
                if ~isempty(lines(ismember(lines,inner.metadata.lines)))
                    coefficients.q{end+1}=1;
                    cons{end+1}=append('q',num,'<=2');
                else
                    coefficients.q{end+1}=0.25;
                end
                cons{end+1}=append('q',num,'-oa',num,'-ob',num,'-oc',num,'-od',num,'==0');
                % check edge direction
                outertarget=outer.target;
                innertarget=inner.target;
                outersource=outer.source;
                innersource=inner.source;
                if outertarget == innersource || outersource == innertarget
                    cons{end+1}=append('a',o,'+a',i,'-2*ua',num,'-oa',num,'==0');
                    cons{end+1}=append('b',o,'+b',i,'-2*ub',num,'-ob',num,'==0');
                    cons{end+1}=append('c',o,'+c',i,'-2*uc',num,'-oc',num,'==0');
                    cons{end+1}=append('d',o,'+d',i,'-2*ud',num,'-od',num,'==0');
                else
                    cons{end+1}=append('a',o,'+b',i,'-2*ua',num,'-oa',num,'==0');
                    cons{end+1}=append('b',o,'+a',i,'-2*ub',num,'-ob',num,'==0');
                    cons{end+1}=append('c',o,'+d',i,'-2*uc',num,'-oc',num,'==0');
                    cons{end+1}=append('c',o,'+d',i,'-2*ud',num,'-od',num,'==0');
                end
                numAdjacentEdgeConstraints=numAdjacentEdgeConstraints+1;
            else
                cons=createOcclusionConstraints(cons,graph,outer,inner);
            end
        end
    end
    % write model
    % add variables
    l=optimvar('l',length(continuous.l),'LowerBound',settings.minEdgeLength,'UpperBound',settings.maxEdgeLength);
    vx=optimvar('vx',length(continuous.vx),'LowerBound',settings.offset-settings.maxWidth/2,'UpperBound',settings.offset+settings.maxWidth/2);
    vy=optimvar('vy',length(continuous.vy),'LowerBound',settings.offset-settings.maxHeight/2,'UpperBound',settings.offset+settings.maxHeight/2);
    pa=optimvar('pa',length(continuous.pa),'LowerBound',0);
    pb=optimvar('pb',length(continuous.pb),'LowerBound',0);
    pc=optimvar('pc',length(continuous.pc),'LowerBound',0);
    pd=optimvar('pd',length(continuous.pd),'LowerBound',0);
    q=optimvar('q',length(integer.q),'LowerBound',0,'UpperBound',3,'Type','integer');
    a=optimvar('a',length(binary.a),'LowerBound',0,'UpperBound',1,'Type','integer');
    b=optimvar('b',length(binary.b),'LowerBound',0,'UpperBound',1,'Type','integer');
    c=optimvar('c',length(binary.c),'LowerBound',0,'UpperBound',1,'Type','integer');
    d=optimvar('d',length(binary.d),'LowerBound',0,'UpperBound',1,'Type','integer');
    h=optimvar('h',length(binary.h),'LowerBound',0,'UpperBound',1,'Type','integer');
    oa=optimvar('oa',length(binary.oa),'LowerBound',0,'UpperBound',1,'Type','integer');
    ob=optimvar('ob',length(binary.ob),'LowerBound',0,'UpperBound',1,'Type','integer');
    oc=optimvar('oc',length(binary.oc),'LowerBound',0,'UpperBound',1,'Type','integer');
    od=optimvar('od',length(binary.od),'LowerBound',0,'UpperBound',1,'Type','integer');
    ua=optimvar('ua',length(binary.ua),'LowerBound',0,'UpperBound',1,'Type','integer');
    ub=optimvar('ub',length(binary.ub),'LowerBound',0,'UpperBound',1,'Type','integer');
    uc=optimvar('uc',length(binary.uc),'LowerBound',0,'UpperBound',1,'Type','integer');
    ud=optimvar('ud',length(binary.ud),'LowerBound',0,'UpperBound',1,'Type','integer');
    % add initial values
    x0.l=settings.offset*ones(length(continuous.l),1);
    x0.vx=settings.offset*ones(length(continuous.vx),1);
    x0.vy=settings.offset*ones(length(continuous.vy),1);
    x0.pa=settings.offset*ones(length(continuous.pa),1);
    x0.pb=settings.offset*ones(length(continuous.pb),1);
    x0.pc=settings.offset*ones(length(continuous.pc),1);
    x0.pd=settings.offset*ones(length(continuous.pd),1);
    x0.q=zeros(length(integer.q),1);
    x0.a=zeros(length(binary.a),1);
    x0.b=zeros(length(binary.b),1);
    x0.c=zeros(length(binary.c),1);
    x0.d=zeros(length(binary.d),1);
    x0.h=zeros(length(binary.h),1);
    x0.oa=zeros(length(binary.oa),1);
    x0.ob=zeros(length(binary.ob),1);
    x0.oc=zeros(length(binary.oc),1);
    x0.od=zeros(length(binary.od),1);
    x0.ua=zeros(length(binary.ua),1);
    x0.ub=zeros(length(binary.ub),1);
    x0.uc=zeros(length(binary.uc),1);
    x0.ud=zeros(length(binary.ud),1);
    % add constraints
    constr='constraints=struct(';
    for conIndex=1:numel(cons)
        constr=append(constr,'''cons',int2str(conIndex),'''',',',cons{conIndex},',');
    end
    constr(end)=[];
    constr=append(constr,')');
    eval(constr);
    % objective function
    lengths='';
    angles='';
    for j=1:numel(continuous.l)
        % weight 3/2
        lengths=append(lengths,'1.5','*',continuous.l{j},'+');
    end
    for k=1:numel(integer.q)
        % weight 1 or 4
        angles=append(angles,'4*',sprintf('%2f',coefficients.q{k}),'*',integer.q{k},'+');
    end
    Minimize=append(angles,lengths);% + in the end
    Minimize(end)=[];
    % input to the problem 
    prob = optimproblem('Objective',eval(Minimize));
    prob.Constraints=constraints;
    % SOLVE IT
    options = optimoptions('intlinprog','Display','off');
    sol = solve(prob,x0,'Options',options);
    Nvx=sol.vx;
    Nvy=sol.vy;
end